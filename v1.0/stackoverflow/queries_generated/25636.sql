WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount,
        p.CreationDate,
        DATEDIFF(CURRENT_TIMESTAMP, p.CreationDate) AS DaysSinceCreation
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag_name
    AS t ON true
    GROUP BY 
        p.Id
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COUNT(c.Id) AS CommentAggregate,
        pt.TagCount,
        pt.DaysSinceCreation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        PostTagCounts pt ON p.Id = pt.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, pt.TagCount, pt.DaysSinceCreation
    HAVING 
        pt.TagCount > 2 AND 
        p.Score > 10
    ORDER BY 
        p.Score DESC
    LIMIT 100
)
SELECT 
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pp.CommentAggregate,
    pp.TagCount,
    pp.DaysSinceCreation,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    u.Location,
    u.Views,
    u.UpVotes,
    u.DownVotes
FROM 
    PopularPosts pp
JOIN 
    Users u ON pp.OwnerUserId = u.Id
ORDER BY 
    pp.ViewCount DESC;
