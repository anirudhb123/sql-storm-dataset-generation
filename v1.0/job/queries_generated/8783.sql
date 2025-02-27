WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword IN ('Action', 'Drama', 'Comedy')
),
AggregatedData AS (
    SELECT 
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT md.actor_name) AS actor_count,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails md
    GROUP BY 
        md.movie_title, md.production_year
)
SELECT 
    ad.movie_title,
    ad.production_year,
    ad.actor_count,
    ad.keywords
FROM 
    AggregatedData ad
ORDER BY 
    ad.production_year DESC, ad.actor_count DESC
LIMIT 10;
