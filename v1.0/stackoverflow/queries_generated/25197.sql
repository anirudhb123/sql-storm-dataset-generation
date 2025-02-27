WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        COALESCE(a.Score, 0) AS AcceptedAnswerScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, a.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.ViewCount,
        rp.AcceptedAnswerScore,
        rp.CommentCount,
        rp.UpVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 -- Top 5 posts per tag based on view count
)
SELECT 
    t.PostId,
    t.Title,
    t.ViewCount,
    t.CommentCount,
    t.UpVoteCount,
    CONCAT('Total Score: ', (t.ViewCount + t.CommentCount + t.UpVoteCount + t.AcceptedAnswerScore)) AS TotalScore,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - t.CreationDate)) / 3600 AS AgeInHours
FROM 
    TopPosts t
ORDER BY 
    TotalScore DESC
LIMIT 10; -- Display the top 10 based on calculated total score
