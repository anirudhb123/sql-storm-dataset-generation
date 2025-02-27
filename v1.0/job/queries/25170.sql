WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

FinalResults AS (
    SELECT 
        r.title,
        r.production_year,
        r.keyword,
        r.num_cast_members,
        ROW_NUMBER() OVER (ORDER BY r.num_cast_members DESC) AS overall_rank
    FROM 
        RankedTitles r
    WHERE 
        r.rank = 1
)

SELECT 
    f.title,
    f.production_year,
    f.keyword,
    f.num_cast_members
FROM 
    FinalResults f
WHERE 
    f.overall_rank <= 10
ORDER BY 
    f.num_cast_members DESC;
