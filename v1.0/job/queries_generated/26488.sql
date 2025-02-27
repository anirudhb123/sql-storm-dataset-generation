WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        a.person_id, ak.name
    HAVING 
        COUNT(ci.movie_id) > 10
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ak.actor_name,
        ci.nr_order,
        string_agg(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        FilteredActors ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.rank <= 5  -- Top 5 Recent Movies Per Year
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ak.actor_name, ci.nr_order
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.nr_order,
    md.keywords,
    md.company_count
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
