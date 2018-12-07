JSON_FILES := $(patsubst %.bin,%.json,$(wildcard *.bin))

json: $(JSON_FILES)

clean:
	rm -f $(JSON_FILES)

%.json: %.fbs %.bin
	flatc -t --raw-binary --defaults-json --strict-json $*.fbs -- $*.bin

.PHONY: json clean
