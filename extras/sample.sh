#! /bin/sh



# Grabs two copies of JBoss AS (6.0.0 and 6.1.0) and uses them to
# produce a timed, multi-processing-enabled run of distdiff with all
# reports enabled, and a profiled (via cProfile) single-process run of
# distdiff with all reports enabled.


# this is currently the closest that we come to having test-suite
# coverage.


OUTPUT_DIR=build/sample
DO_TIMED=
DO_PROFILED=



for arg in "$@" ; do
    case "$arg" in 
	--help)
	    echo "Usage: $0 [OPTIONS]"
	    echo "Fetches sample distributions and runs a full report"
	    echo
	    echo " Options:"
	    echo "   --help     print this message"
	    echo "   --time     run a timed report"
	    echo "   --profile  run a profiled report"
            echo "   --all      run both timed and profiled reports"
	    echo "   --output=DIR directory to write work into"
	    echo
	    exit 1
	    ;;

	--time)
	    DO_TIMED=1
	    ;;

	--profile)
	    DO_PROFILED=1
	    ;;

	--all)
	    DO_TIMED=1
	    DO_PROFILED=1
	    ;;

	--output=*)
	    OUTPUT_DIR="${arg#--output=}"
	    ;;
    esac
done



SAMPLE_URL_LEFT=http://sourceforge.net/projects/jboss/files/JBoss/JBoss-6.0.0.Final/jboss-as-distribution-6.0.0.Final.zip/download
SAMPLE_FILE_LEFT=$OUTPUT_DIR/jboss-as-distribution-6.0.0.Final.zip
SAMPLE_DIR_LEFT=$OUTPUT_DIR/jboss-6.0.0.Final

SAMPLE_URL_RIGHT=http://download.jboss.org/jbossas/6.1/jboss-as-distribution-6.1.0.Final.zip
SAMPLE_FILE_RIGHT=$OUTPUT_DIR/jboss-as-distribution-6.1.0.Final.zip
SAMPLE_DIR_RIGHT=$OUTPUT_DIR/jboss-6.1.0.Final



mkdir -p $OUTPUT_DIR



echo "Fetching sample data if needed"
if test ! -d "$SAMPLE_DIR_LEFT" ; then
    if test ! -f "$SAMPLE_FILE_LEFT" ; then
	wget -c "$SAMPLE_URL_LEFT" -O "$SAMPLE_FILE_LEFT"
    fi
    unzip -q "$SAMPLE_FILE_LEFT" -d "$OUTPUT_DIR/"
fi

if test ! -d "$SAMPLE_DIR_RIGHT" ; then
    if test ! -f "$SAMPLE_FILE_RIGHT" ; then
	wget -c "$SAMPLE_URL_RIGHT" -O "$SAMPLE_FILE_RIGHT"
    fi
    unzip -q "$SAMPLE_FILE_RIGHT" -d "$OUTPUT_DIR/"
fi



function run_timed() {
    echo "Running full-speed report for timing"

    PYTHONPATH=build/lib/ \
	/usr/bin/time -v -o $OUTPUT_DIR/distdiff.time \
	build/scripts-2.7/distdiff \
	-q --show-ignored \
	--ignore=version,platform,lines,pool \
	--ignore=manifest_subsections,jar_signature \
	--ignore=trailing_whitespace \
	--report=html,txt,json \
	--report=html,txt,json \
	--report-dir=$OUTPUT_DIR/timed/reports \
	--html-copy-data=$OUTPUT_DIR/timed/resources \
	"$SAMPLE_DIR_LEFT" "$SAMPLE_DIR_RIGHT"

    cat $OUTPUT_DIR/distdiff.time
    echo "Timing data saved at $OUTPUT_DIR/distdiff.time"
}



function run_profiled() {
    echo "Running single-process report for profiling dump"

    PYTHONPATH=build/lib/ \
	python -m cProfile -o $OUTPUT_DIR/distdiff.dump \
	build/scripts-2.7/distdiff \
	-q --show-ignored --processes=0 \
	--ignore=version,platform,lines,pool \
	--ignore=manifest_subsections,jar_signature \
	--ignore=trailing_whitespace \
	--report=html,txt,json \
	--report-dir=$OUTPUT_DIR/profiled/reports \
	--html-copy-data=$OUTPUT_DIR/profiled/resources \
	"$SAMPLE_DIR_LEFT" "$SAMPLE_DIR_RIGHT"

    echo "Profiling data saved at $OUTPUT_DIR/distdiff.dump"
}



echo "Building"
./setup.py pylint || exit 1



if test "$DO_TIMED" ; then
    run_timed
fi


if test "$DO_PROFILED" ; then
    run_profiled
fi



#
# The end.
