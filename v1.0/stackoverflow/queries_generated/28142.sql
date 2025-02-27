WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN a.Id END) AS AnsweredCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Tags
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.AnsweredCount,
    CONCAT('https://stackoverflow.com/questions/', rp.PostId) AS PostLink
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5 -- Top 5 posts per tag
ORDER BY 
    rp.Tags, rp.CommentCount DESC;
