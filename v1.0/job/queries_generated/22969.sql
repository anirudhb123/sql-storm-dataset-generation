WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) as rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
AggregatedActorData AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN a.gender IS NULL THEN 0 ELSE 1 END) AS gender_discrepancy
    FROM 
        cast_info c
    LEFT JOIN 
        name a ON c.person_id = a.id
    GROUP BY 
        c.movie_id
),
MoviesWithCompanies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mc.company_id,
        cn.name AS company_name
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
),
TopMovies AS (
    SELECT 
        mw.movie_id,
        mw.title,
        mw.production_year,
        mw.company_name,
        COALESCE(ad.actor_count, 0) AS actor_count,
        COALESCE(ad.gender_discrepancy, 0) AS gender_discrepancy,
        RANK() OVER (ORDER BY mw.production_year DESC, ad.actor_count DESC) AS movie_rank
    FROM 
        MoviesWithCompanies mw
    LEFT JOIN 
        AggregatedActorData ad ON mw.movie_id = ad.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_name,
    tm.actor_count,
    tm.gender_discrepancy,
    CASE 
        WHEN tm.gender_discrepancy > 0 THEN 'Discrepant Gender'
        WHEN tm.gender_discrepancy = 0 AND tm.actor_count > 5 THEN 'Well Cast'
        ELSE 'Underwhelming Cast'
    END AS cast_quality,
    CASE 
        WHEN tm.actor_count IS NULL THEN 'Data Not Available'
        ELSE CAST(tm.actor_count AS TEXT)
    END AS actor_count_str,
    (SELECT COUNT(DISTINCT k.keyword) 
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = tm.movie_id) AS keyword_count
FROM 
    TopMovies tm
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
