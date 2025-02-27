WITH PostAuthorStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(DISTINCT v.PostId) AS UniqueVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ps.TotalPosts, 0) AS PostsMade,
    COALESCE(ps.TotalQuestions, 0) AS QuestionsAsked,
    COALESCE(ps.TotalAnswers, 0) AS AnswersProvided,
    COALESCE(ubs.BadgeCount, 0) AS TotalBadges,
    COALESCE(ubs.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubs.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(vs.UniqueVotes, 0) AS TotalUniqueVotes,
    COALESCE(vs.UpVotesCount, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotesCount, 0) AS TotalDownVotes,
    COALESCE(ps.LastPostDate, 'No Posts Yet') AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    PostAuthorStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    UserBadges ubs ON u.Id = ubs.UserId
LEFT JOIN 
    UserVoteStats vs ON u.Id = vs.UserId
WHERE 
    u.Reputation > (
        SELECT AVG(Reputation) FROM Users
    ) 
    OR (
        SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id
    ) > 5
ORDER BY 
    u.Reputation DESC
FETCH FIRST 100 ROWS ONLY;
