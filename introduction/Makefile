ALL: .basics_updated .details_updated

.basics_updated: basics.yml
	./go.py basics
	touch $@

.details_updated: details.yml
	./go.py details
	touch $@
