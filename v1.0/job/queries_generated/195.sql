WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
),
PersonDetails AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movies_acted_in,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM aka_name a
    LEFT JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.person_id
),
TopActors AS (
    SELECT 
        pd.actor_names,
        pd.movies_acted_in,
        ROW_NUMBER() OVER (ORDER BY pd.movies_acted_in DESC) AS rank
    FROM PersonDetails pd
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.company_count,
    ta.actor_names,
    ta.movies_acted_in
FROM MovieDetails md
LEFT JOIN TopActors ta ON ta.rank <= 10
ORDER BY md.production_year DESC, md.title_id;
