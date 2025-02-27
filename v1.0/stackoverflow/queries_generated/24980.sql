WITH PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (6, 10, 12) THEN 1 END) AS CloseVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserBadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
QuestionDetail AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        Q.AnswerCount,
        COALESCE(VS.UpVotes - VS.DownVotes, 0) AS Score,
        UB.BadgeCount,
        UB.BadgeNames
    FROM 
        Posts P
    JOIN 
        PostVoteSummary VS ON P.Id = VS.PostId
    LEFT JOIN 
        UserBadgeSummary UB ON P.OwnerUserId = UB.UserId
    LEFT JOIN 
        (SELECT 
            ParentId, COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId) Q ON P.Id = Q.ParentId
    WHERE 
        P.PostTypeId = 1
)
SELECT 
    QD.QuestionId,
    QD.Title,
    QD.CreationDate,
    U.DisplayName,
    COALESCE(QD.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(QD.BadgeNames, 'No Badges') AS UserBadges,
    QD.Score,
    CASE 
        WHEN QD.Score <= 0 OR QD.BadgeCount IS NULL THEN 'Inactive'
        WHEN QD.Score > 0 AND QD.BadgeCount > 0 THEN 'Active with Badges'
        ELSE 'Active without Badges'
    END AS UserStatus
FROM 
    QuestionDetail QD
JOIN 
    Users U ON QD.OwnerUserId = U.Id
WHERE 
    QD.Score > (SELECT AVG(Score) FROM QuestionDetail)
ORDER BY 
    QD.Score DESC, QD.CreationDate ASC
LIMIT 15
OFFSET 5;

-- Additional query to count total posts, badges, and average upvotes/downvotes
SELECT 
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT B.Id) AS TotalBadges,
    AVG(VS.UpVotes) AS AverageUpVotes,
    AVG(VS.DownVotes) AS AverageDownVotes
FROM 
    Posts P
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON P.OwnerUserId = B.UserId
LEFT JOIN 
    PostVoteSummary VS ON P.Id = VS.PostId
WHERE 
    P.CreationDate > (CURRENT_DATE - INTERVAL '1 year')
GROUP BY 
    P.PostTypeId;

-- A string expression with complex predicates
SELECT 
    P.Id,
    CASE 
        WHEN P.Body ~ '^(Introduction|Hello)' THEN 'Greeting Post'
        WHEN P.Body ILIKE '%bug%' THEN 'Bug Report'
        WHEN LENGTH(P.Body) < 100 THEN 'Short Post'
        ELSE 'General Post'
    END AS PostTypeDescription
FROM 
    Posts P
WHERE 
    P.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
    AND COALESCE(P.ClosedDate, '2999-12-31') > CURRENT_DATE
ORDER BY 
    P.Score DESC
LIMIT 10;
