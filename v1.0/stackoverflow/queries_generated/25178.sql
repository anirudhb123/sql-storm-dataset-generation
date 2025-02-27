WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS t ON t.TagName = t.TagName
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
PostStats AS (
    SELECT 
        r.PostID,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        RankedPosts r
    LEFT JOIN 
        Comments c ON r.PostID = c.PostId
    LEFT JOIN 
        Votes v ON r.PostID = v.PostId
    GROUP BY 
        r.PostID
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.TagsList,
    ps.CommentCount,
    ps.VoteCount,
    (rp.Score + ps.VoteCount) AS EngagementScore
FROM 
    RankedPosts rp
JOIN 
    PostStats ps ON rp.PostID = ps.PostID
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    EngagementScore DESC;
