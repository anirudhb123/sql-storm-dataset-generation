WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 4 THEN 1 ELSE 0 END), 0) AS TagWikiExcerptCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 5 THEN 1 ELSE 0 END), 0) AS TagWikiCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
), RankedActivity AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        TagWikiExcerptCount,
        TagWikiCount,
        TotalBounty,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN QuestionCount >= AnswerCount THEN 'QuestionMaster'
            ELSE 'AnswerMaster'
        END ORDER BY Reputation DESC) AS ActivityClassification
    FROM 
        UserActivity
), UserBadges AS (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS RecentBadgeRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RA.DisplayName,
    RA.Reputation,
    RA.QuestionCount,
    RA.AnswerCount,
    OA.BadgeNames,
    RA.TotalBounty,
    RA.UserRank,
    CASE 
        WHEN RA.ActivityClassification = 1 THEN 'Question Master'
        WHEN RA.ActivityClassification = 2 THEN 'Answer Master'
        ELSE 'Other'
    END AS MasterStatus,
    CASE 
        WHEN RA.TotalBounty = 0 THEN 'No Bounties'
        ELSE 'Bounties Available'
    END AS BountyStatus
FROM 
    RankedActivity RA
LEFT JOIN 
    UserBadges OA ON RA.UserId = OA.UserId
WHERE 
    RA.QuestionCount + RA.AnswerCount > 5 
    AND (RA.TotalBounty IS NOT NULL AND RA.TotalBounty > 0)
    AND (SELECT COUNT(*) FROM UserBadges WHERE UserId = RA.UserId AND RecentBadgeRank = 1) > 0
ORDER BY 
    RA.Reputation DESC,
    RA.QuestionCount DESC,
    RA.AnswerCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
This query performs multiple steps: First, it aggregates user activity related to posts and votes, creates ranking for user contributions, and fetches additional details on badges owned by users, integrating various complex SQL constructs such as CTEs, window functions, and conditional logic. It then selects users with significant contributions and active bounties while accounting for their badges, sorting the results methodically.
