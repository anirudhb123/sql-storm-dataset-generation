WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only for Questions
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName AS UserDisplayName,
    rp.Title,
    rp.CommentCount,
    rp.AnswerCount,
    rp.ViewCount,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    rp.Rank
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
WHERE 
    rp.Rank <= 10 -- Top 10 questions per user
ORDER BY 
    u.DisplayName, rp.Score DESC;
