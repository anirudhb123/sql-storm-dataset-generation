
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > DATEADD(DAY, -30, '2024-10-01')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
), 
PopularTags AS (
    SELECT 
        TRIM(split_part(t.Tag, '>', i)) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        (SELECT Tags, ROW_NUMBER() OVER() AS rn FROM Posts WHERE CreationDate > DATEADD(DAY, -30, '2024-10-01')) t,
        LATERAL FLATTEN(input => SPLIT(t.Tags, '>')) AS i
    GROUP BY 
        Tag
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    pt.Tag,
    pt.TagCount
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Title LIKE '%' || pt.Tag || '%'
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CommentCount DESC, rp.UpVoteCount DESC
LIMIT 10;
