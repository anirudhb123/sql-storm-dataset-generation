WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.kind_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(RANK() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC)) AS avg_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = mt.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    WHERE 
        mt.production_year IS NOT NULL
        AND (mi.info LIKE '%Oscar%' OR mk.keyword LIKE '%Award%') -- Movies that are award-winning or nominated
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
),
CompanyStats AS (
    SELECT 
        m.id AS movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies m
    JOIN 
        company_name c ON c.id = m.company_id
    JOIN 
        company_type ct ON ct.id = m.company_type_id
    GROUP BY 
        m.id, c.name, ct.kind
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        cs.company_name,
        cs.company_type,
        rm.actor_count,
        ROW_NUMBER() OVER (PARTITION BY cs.company_type ORDER BY rm.actor_count DESC) AS rn
    FROM 
        RankedMovies rm
    JOIN 
        CompanyStats cs ON cs.movie_id = rm.id
)
SELECT 
    tm.*,
    CASE 
        WHEN tm.actor_count > 5 THEN 'Ensemble Cast'
        WHEN tm.actor_count IS NULL THEN 'No Cast Information'
        ELSE 'Low Cast Count'
    END AS cast_description
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 3 
ORDER BY 
    tm.company_type, tm.actor_count DESC;

-- Adding CTE to include the average movie length if we had such data (bizarre constraint for illustration)
WITH AverageLength AS (
    SELECT 
        m.movie_id,
        AVG(m.length) AS avg_length -- Assuming 'length' is a column which is not present in the current schema.
    FROM 
        movie_info m
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.*,
    COALESCE(AL.avg_length, 'Length Unknown') AS avg_movie_length -- Using COALESCE for NULL logic
FROM 
    TopMovies tm
LEFT JOIN 
    AverageLength AL ON AL.movie_id = tm.id
ORDER BY 
    tm.company_type, tm.actor_count DESC;
