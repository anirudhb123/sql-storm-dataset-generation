WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END) AS HistoryEditCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    SUM(pi.CommentCount) AS TotalComments,
    SUM(pi.HistoryEditCount) AS TotalEdits,
    ua.UpVotes,
    ua.DownVotes,
    CASE 
        WHEN ua.UpVotes > ua.DownVotes THEN 'Active Contributor'
        WHEN ua.UpVotes < ua.DownVotes THEN 'Concerning Activity'
        ELSE 'Neutral Activity'
    END AS ActivityStatus
FROM 
    UserActivity ua
LEFT JOIN 
    UserBadges ub ON ua.UserId = ub.UserId
LEFT JOIN 
    PostInteraction pi ON ua.UserId = pi.OwnerUserId
WHERE 
    ua.UserRank <= 10
GROUP BY 
    ua.UserId, ua.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    ua.PostCount DESC, ua.DisplayName;
