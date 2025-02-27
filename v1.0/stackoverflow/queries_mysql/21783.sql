
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @row_number := IF(@prev_location = u.Location, @row_number + 1, 1) AS UserRank,
        @prev_location := u.Location,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedAnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_number := 0, @prev_location := '') AS rn
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Location
)

SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.UserRank,
    ru.BadgeCount,
    (ru.UpvoteCount - ru.DownvoteCount) AS VoteBalance,
    ru.AcceptedAnswersCount,
    CASE 
        WHEN ru.UserRank = 1 THEN 'Top User'
        WHEN ru.UserRank <= 3 THEN 'Top 3 Users'
        ELSE 'Regular User'
    END AS UserType,
    COALESCE((SELECT GROUP_CONCAT(t.TagName SEPARATOR ', ') 
              FROM Tags t 
              JOIN Posts p ON t.ExcerptPostId = p.Id 
              WHERE p.OwnerUserId = ru.UserId), 'No Tags') AS UserTags
FROM 
    RankedUsers ru
WHERE 
    ru.UserRank <= 5
ORDER BY 
    ru.UserRank;
