WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        COUNT(*) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY COUNT(*) DESC) AS rn
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName)
    GROUP BY 
        p.Id, t.TagName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount
),
TopTags AS (
    SELECT 
        TagCount, 
        TagName 
    FROM 
        PostTagCounts 
    WHERE 
        rn = 1
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    t.TagName
FROM 
    TopPosts tp
JOIN 
    TopTags t ON t.TagName IN (SELECT TagName FROM PostTagCounts WHERE PostId = tp.PostId)
WHERE 
    tp.rn <= 20
ORDER BY 
    tp.ViewCount DESC, tp.CommentCount DESC;
