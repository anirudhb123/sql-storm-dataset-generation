WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY p.OwnerUserId) AS QuestionsByUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalStats AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ubs.BadgeCount,
        ubs.LastBadgeDate,
        CASE 
            WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'Positive' 
            WHEN ps.UpVoteCount < ps.DownVoteCount THEN 'Negative' 
            ELSE 'Neutral' 
        END AS Sentiment,
        CASE 
            WHEN ps.QuestionsByUser > 5 THEN 'Active Contributor' 
            ELSE 'New User' 
        END AS UserActivityLevel
    FROM 
        PostStats ps
    JOIN 
        Users u ON ps.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadgeStats ubs ON u.Id = ubs.UserId
)
SELECT 
    p.Title,
    fs.CommentCount,
    fs.UpVoteCount,
    fs.DownVoteCount,
    fs.BadgeCount,
    COALESCE(fs.LastBadgeDate, 'No Badges') AS LastBadge,
    fs.Sentiment,
    fs.UserActivityLevel
FROM 
    FinalStats fs
JOIN 
    Posts p ON fs.PostId = p.Id
WHERE 
    fs.CommentCount > 0 AND
    (fs.BadgeCount > 0 OR fs.Sentiment = 'Positive')
ORDER BY 
    fs.UpVoteCount DESC, 
    fs.CommentCount ASC;
