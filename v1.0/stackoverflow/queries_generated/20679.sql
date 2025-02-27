WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostVoteSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.OwnerUserId
),
PostAnswerDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(a.Score, 0) AS AnswerScore,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Posts a2 
             WHERE a2.ParentId = p.Id AND a2.PostTypeId = 2), 0) AS AnswerCount
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1
),
RankedUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        up.BadgeCount,
        up.GoldBadges,
        up.SilverBadges,
        up.BronzeBadges,
        COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
        COALESCE(pvs.UpVotes, 0) AS UserUpVotes,
        COALESCE(pvs.DownVotes, 0) AS UserDownVotes,
        ROW_NUMBER() OVER (ORDER BY up.Reputation DESC) AS Rank
    FROM Users ub
    JOIN UserBadges up ON ub.Id = up.UserId
    LEFT JOIN PostVoteSummary pvs ON ub.Id = pvs.OwnerUserId
)
SELECT 
    ru.Rank,
    ru.DisplayName,
    ru.BadgeCount,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    CASE 
        WHEN ru.TotalVotes > 0 THEN ROUND((ru.UserUpVotes::decimal / ru.TotalVotes) * 100, 2)
        ELSE 0
    END AS UpVotePercentage,
    COALESCE(pd.AnswerCount, 0) AS TotalAnswers,
    COALESCE(pd.AcceptedAnswerId, -1) AS AcceptedAnswer,
    COALESCE((
        SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM TAGS t
        JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
        WHERE p.OwnerUserId = ru.UserId 
        AND p.PostTypeId = 1
    ), 'No Tags') AS PopularTags
FROM RankedUsers ru
LEFT JOIN PostAnswerDetails pd ON ru.UserId = pd.OwnerUserId
WHERE ru.Rank <= 10
ORDER BY ru.Rank;
