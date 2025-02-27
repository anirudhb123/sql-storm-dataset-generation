WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS genre_rank
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        kt.kind IN ('Action', 'Comedy', 'Drama')
),
ActorCompensation AS (
    SELECT 
        ca.person_id,
        SUM(CASE 
            WHEN ci.note IS NULL THEN 1000 
            ELSE 500 
        END) AS total_compensation
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ca.person_id
),
MovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(cn.name, 'Unknown Company') AS production_company,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        RANK() OVER (PARTITION BY m.id ORDER BY mk.keyword) AS keyword_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
)
SELECT 
    rd.title_id,
    rd.title,
    rd.production_year,
    ac.person_id,
    COALESCE(ac.total_compensation, 0) AS actor_compensation,
    md.production_company,
    md.keyword,
    md.keyword_rank
FROM 
    RankedMovies rd
LEFT JOIN 
    ActorCompensation ac ON (rd.title_id IN (SELECT movie_id FROM cast_info WHERE person_id = ac.person_id))
LEFT JOIN 
    MovieData md ON rd.title_id = md.movie_id
WHERE 
    rd.genre_rank <= 5
ORDER BY 
    rd.production_year DESC,
    ac.total_compensation DESC NULLS LAST,
    md.keyword_rank
LIMIT 50;
