
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        COALESCE(cnt.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) cnt ON p.Id = cnt.PostId
),
UserEngagement AS (
    SELECT
        u.Id AS UserID,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > (NOW() - INTERVAL 30 DAY)
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        GROUP_CONCAT(DISTINCT p.Title SEPARATOR ', ') AS PostTitles,
        GROUP_CONCAT(DISTINCT a.Title SEPARATOR ', ') AS RelatedAnswers
    FROM 
        Tags t
    LEFT JOIN Posts p ON t.Id = p.Id
    LEFT JOIN Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    GROUP BY 
        t.TagName
)
SELECT 
    rp.PostID,
    rp.Title,
    u.DisplayName AS Author,
    u.Reputation,
    COALESCE(ueng.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ueng.DownVotes, 0) AS TotalDownVotes,
    ts.PostCount AS TagPostCount,
    ts.PostTitles AS TagPostTitles,
    ra.UserId AS RecentActivityUser,
    ra.CreationDate AS RecentActivityDate,
    CASE 
        WHEN ra.PostHistoryTypeId IN (10, 11) THEN 'Closed or Reopened' 
        ELSE 'Other Activity'
    END AS ActivityType
FROM 
    RankedPosts rp
JOIN Users u ON u.Id = rp.PostID 
LEFT JOIN UserEngagement ueng ON ueng.UserID = u.Id
LEFT JOIN RecentActivity ra ON ra.PostId = rp.PostID
LEFT JOIN TagStatistics ts ON ts.TagName IN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Title, ' ', numbers.n), ' ', -1)) 
                                                FROM 
                                                (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                                                 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
                                                WHERE CHAR_LENGTH(rp.Title) - CHAR_LENGTH(REPLACE(rp.Title, ' ', '')) >= numbers.n - 1)
WHERE 
    rp.CommentCount > 5 
    AND (u.Reputation BETWEEN 100 AND 1000 OR 
    (ueng.TotalVotes > 5 AND ts.PostCount > 1))
ORDER BY 
    rp.CreationDate DESC, 
    COALESCE(ueng.UpVotes, 0) DESC
LIMIT 50;
