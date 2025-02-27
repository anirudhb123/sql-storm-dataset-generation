WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(k.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        kind_id, 
        keyword_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    TM.title,
    TM.production_year,
    k.kind,
    COALESCE(CAST(ca.name AS TEXT), 'Unknown') AS actor_name,
    CA.person_id,
    COUNT(DISTINCT p.id) AS person_info_count
FROM 
    TopMovies TM
JOIN 
    kind_type k ON TM.kind_id = k.id
LEFT JOIN 
    complete_cast cc ON TM.id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.id
LEFT JOIN 
    aka_name an ON ca.person_id = an.person_id
LEFT JOIN 
    person_info p ON ca.person_id = p.person_id
WHERE 
    TM.rank <= 5
GROUP BY 
    TM.title, TM.production_year, k.kind, ca.id, an.name
ORDER BY 
    TM.production_year DESC, TM.keyword_count DESC;
