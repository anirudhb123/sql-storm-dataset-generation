WITH RankedMovies AS (
    SELECT 
        ak.id AS aka_id,
        ak.name AS aka_name,
        at.title AS movie_title,
        at.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    LEFT JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        ak.id, ak.name, at.id, at.title, at.production_year
),
MostActiveActors AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
FinalResults AS (
    SELECT 
        rm.aka_name,
        rm.movie_title,
        rm.production_year,
        ma.actor_name,
        rm.companies,
        rm.keywords
    FROM 
        RankedMovies rm
    JOIN 
        MostActiveActors ma ON rm.aka_id = ma.actor_id
    ORDER BY 
        rm.production_year DESC, ma.movie_count DESC
)
SELECT * FROM FinalResults
LIMIT 50;
