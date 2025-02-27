
WITH PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(p.CreationDate) AS LastActivity,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title
), PostRanked AS (
    SELECT 
        ps.Id,
        ps.Title,
        ps.CommentCount,
        ps.AnswerCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.LastActivity,
        ps.BadgeCount,
        @rank := IF(@prev_val = (ps.UpVoteCount - ps.DownVoteCount), @rank, @rank + 1) AS Rank,
        @prev_val := (ps.UpVoteCount - ps.DownVoteCount)
    FROM 
        PostStats ps, (SELECT @rank := 0, @prev_val := NULL) AS vars
    ORDER BY 
        (ps.UpVoteCount - ps.DownVoteCount) DESC, ps.CommentCount DESC
)
SELECT 
    pr.Id,
    pr.Title,
    pr.CommentCount,
    pr.AnswerCount,
    pr.UpVoteCount,
    pr.DownVoteCount,
    pr.Rank,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
    u.Reputation
FROM 
    PostRanked pr
LEFT JOIN 
    Users u ON pr.Id = u.AccountId
WHERE 
    pr.Rank <= 100
ORDER BY 
    pr.Rank;
