WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(mci.note, 'No Company Info') AS company_note,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
        LEFT JOIN movie_companies mc ON t.id = mc.movie_id
        LEFT JOIN company_name mci ON mc.company_id = mci.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
        JOIN keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
        JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_note,
    mk.keywords,
    cd.total_actors,
    cd.actor_names
FROM 
    RankedMovies rm
    LEFT JOIN MovieKeywords mk ON rm.rn = mk.movie_id
    LEFT JOIN CastDetails cd ON rm.rn = cd.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC;
