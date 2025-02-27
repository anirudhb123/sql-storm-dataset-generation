WITH MovieRankings AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    GROUP BY 
        t.title, t.production_year
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(DISTINCT ci.movie_id) AS filmography_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.person_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(cc.company_count, 0) AS total_companies,
    AVG(ai.filmography_count) AS avg_actor_filmography
FROM 
    MovieRankings m
LEFT JOIN 
    CompanyCounts cc ON m.id = cc.movie_id
LEFT JOIN 
    ActorInfo ai ON ai.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = m.id)
LEFT JOIN 
    (SELECT DISTINCT a.title, r.production_year FROM aka_title a JOIN MovieRankings r ON a.production_year = r.production_year) ac ON true
WHERE 
    m.rank_in_year <= 10
GROUP BY 
    m.title, m.production_year
HAVING 
    AVG(ai.filmography_count) > 5
ORDER BY 
    m.production_year DESC, total_actors DESC;
