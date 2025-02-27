
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.AcceptedAnswers,
        @row_number := IF(@current_owner_user_id = ps.OwnerUserId, @row_number + 1, 1) AS UserRank,
        @current_owner_user_id := ps.OwnerUserId
    FROM 
        PostStats ps, (SELECT @row_number := 0, @current_owner_user_id := NULL) AS vars
    ORDER BY
        ps.OwnerUserId, ps.UpVotes DESC
)
SELECT 
    ub.DisplayName AS UserName,
    ub.BadgeCount,
    ub.BadgeNames,
    pd.PostId,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.AcceptedAnswers,
    pd.UserRank
FROM 
    UserBadges ub
LEFT JOIN 
    PostDetails pd ON ub.UserId = pd.OwnerUserId
WHERE 
    pd.CommentCount > 0
ORDER BY 
    ub.BadgeCount DESC,
    pd.UserRank
LIMIT 10;
