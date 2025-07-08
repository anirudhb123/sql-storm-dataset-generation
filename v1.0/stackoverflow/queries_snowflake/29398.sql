
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        LISTAGG(b.Name, ', ') WITHIN GROUP (ORDER BY b.Name) AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL FLATTEN(input => SPLIT(p.Tags, '>')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag.value
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount
),

VoteSummaries AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId IN (3, 10) THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.BadgeCount,
    ub.Badges,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.ViewCount,
    ps.Score AS PostScore,
    ps.AnswerCount,
    ps.CommentCount,
    ps.Tags,
    vs.UpVotes,
    vs.DownVotes,
    vs.TotalVotes
FROM 
    Users u
JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    Posts p ON u.Id = p.OwnerUserId
JOIN 
    PostStatistics ps ON ps.PostId = p.Id
LEFT JOIN 
    VoteSummaries vs ON ps.PostId = vs.PostId
ORDER BY 
    ub.BadgeCount DESC, ps.ViewCount DESC
LIMIT 50;
