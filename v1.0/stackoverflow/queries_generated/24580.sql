WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FinalReport AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.UpVotes - us.DownVotes AS NetVotes, 
        COUNT(rp.PostId) AS QuestionCount,
        STRING_AGG(rp.Title, ', ') AS RecentQuestions,
        MAX(rp.CreationDate) AS LatestPostDate,
        us.EditCount
    FROM 
        UserStatistics us
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId
    GROUP BY 
        us.UserId, us.DisplayName, us.Reputation, us.EditCount
)
SELECT 
    *,
    CASE 
        WHEN LatestPostDate IS NOT NULL THEN DATEDIFF(DAY, LatestPostDate, GETDATE()) 
        ELSE NULL 
    END AS DaysSinceLastPost,
    CASE 
        WHEN EditCount > 0 THEN 'Active Editor' 
        ELSE 'Inactive Editor' 
    END AS EditStatus
FROM 
    FinalReport
ORDER BY 
    NetVotes DESC,
    Reputation DESC
LIMIT 10;
