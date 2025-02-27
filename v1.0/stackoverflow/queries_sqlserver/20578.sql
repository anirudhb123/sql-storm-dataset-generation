
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS Reasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INT) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(DATEDIFF(SECOND, p.CreationDate, CAST('2024-10-01 12:34:56' AS DATETIME)), 0)) AS AvgPostAgeInSeconds
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
FinalReport AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.TotalScore,
        us.AvgPostAgeInSeconds,
        rq.PostId,
        rq.Title,
        rq.UpVotes,
        rq.DownVotes,
        cr.Reasons
    FROM 
        UserStatistics us
    JOIN 
        RankedPosts rq ON us.UserId = rq.OwnerUserId
    LEFT JOIN 
        CloseReasons cr ON rq.PostId = cr.PostId
    WHERE 
        rq.PostRank = 1
)

SELECT 
    fr.DisplayName,
    fr.PostCount,
    fr.TotalScore,
    (CASE 
         WHEN fr.AvgPostAgeInSeconds IS NULL THEN 'New User' 
         WHEN fr.AvgPostAgeInSeconds < 604800 THEN 'Newly Active'
         ELSE 'Long-Term User' 
     END) AS UserType,
    STRING_AGG(DISTINCT fr.Reasons, '; ') AS CloseReasons
FROM 
    FinalReport fr
GROUP BY 
    fr.DisplayName, fr.PostCount, fr.TotalScore, fr.AvgPostAgeInSeconds
ORDER BY 
    fr.TotalScore DESC, fr.DisplayName
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
