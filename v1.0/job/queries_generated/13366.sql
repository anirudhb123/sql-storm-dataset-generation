SELECT
    title.title AS movie_title,
    aka_name.name AS actor_name,
    company_name.name AS production_company,
    movie_info.info AS movie_info,
    keyword.keyword AS movie_keyword
FROM
    title
JOIN
    aka_title ON title.id = aka_title.movie_id
JOIN
    cast_info ON aka_title.id = cast_info.movie_id
JOIN
    aka_name ON cast_info.person_id = aka_name.person_id
JOIN
    movie_companies ON title.id = movie_companies.movie_id
JOIN
    company_name ON movie_companies.company_id = company_name.id
JOIN
    movie_info ON title.id = movie_info.movie_id
JOIN
    movie_keyword ON title.id = movie_keyword.movie_id
JOIN
    keyword ON movie_keyword.keyword_id = keyword.id
WHERE
    title.production_year > 2000
ORDER BY
    title.production_year DESC, title.title, actor_name;
