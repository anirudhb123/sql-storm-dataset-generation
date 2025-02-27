WITH RecursiveActorTitles AS (
    SELECT 
        ka.person_id,
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY kt.production_year DESC) AS title_rank
    FROM 
        aka_name AS ka
    JOIN 
        cast_info AS ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title AS kt ON ci.movie_id = kt.movie_id 
    WHERE 
        kt.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT 
        rat.person_id,
        rat.actor_name,
        COUNT(rat.movie_title) AS movie_count,
        STRING_AGG(DISTINCT rat.movie_title || ' (' || rat.production_year || ')', ', ') AS movie_titles
    FROM 
        RecursiveActorTitles AS rat
    GROUP BY 
        rat.person_id,
        rat.actor_name
),
NullInfoType AS (
    SELECT 
        p.id AS person_id,
        p.name,
        pi.info AS person_info
    FROM 
        name AS p
    LEFT JOIN 
        person_info AS pi ON p.id = pi.person_id 
    WHERE 
        pi.info IS NULL
)
SELECT 
    ami.actor_name,
    ami.movie_count,
    ami.movie_titles,
    ni.person_info
FROM 
    ActorMovieInfo AS ami
LEFT JOIN 
    NullInfoType AS ni ON ami.person_id = ni.person_id
WHERE 
    ami.movie_count > 5
ORDER BY 
    ami.movie_count DESC,
    ami.actor_name ASC
LIMIT 10;

-- Include edge case handling to check for NULL values in title ranks
SELECT 
    ct.id AS title_category_id,
    ct.kind AS title_category,
    COUNT(DISTINCT ct2.title) AS total_titles,
    SUM(CASE 
            WHEN ct2.production_year IS NULL THEN 1 
            ELSE 0 
        END) AS missing_years
FROM 
    kind_type AS ct
LEFT JOIN 
    aka_title AS ct2 ON ct.id = ct2.kind_id
GROUP BY 
    ct.id, ct.kind
HAVING 
    COUNT(DISTINCT ct2.title) > 20
ORDER BY 
    total_titles DESC;

-- Cross join artistic titles that are classified with keywords, using semi-structured logic
SELECT 
    DISTINCT at.movie_title,
    k.keyword AS associated_keyword
FROM 
    aka_title AS at
JOIN 
    movie_keyword AS mk ON at.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    k.keyword IS NOT NULL AND
    k.keyword <> ''
EXCEPT 
SELECT 
    at.movie_title,
    k.keyword
FROM 
    aka_title AS at
JOIN 
    movie_keyword AS mk ON at.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    k.keyword LIKE 'Horror%'
ORDER BY 
    associated_keyword;
