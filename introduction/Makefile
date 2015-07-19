ALL: .basics_updated .details_updated .goals_updated

.basics_updated: basics.yml
	./go.py $(basename $<)
	touch $@

.details_updated: details.yml
	./go.py $(basename $<)
	touch $@

.goals_updated: goals.yml
	./go.py $(basename $<)
	touch $@
