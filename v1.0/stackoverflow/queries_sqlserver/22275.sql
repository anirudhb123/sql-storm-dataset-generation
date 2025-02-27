
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0) 
        AND p.OwnerUserId IS NOT NULL
), 
PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 5) THEN v.Id END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount ELSE 0 END) AS TotalBounty
    FROM 
        Votes v
    GROUP BY 
        v.PostId
), 
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment = CAST(c.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalBounty,
    COALESCE(cpr.CloseReasons, 'Not Closed') AS CloseReasonsDetails,
    CASE 
        WHEN rp.RecentPostRank = 1 THEN 'Most Recent Post'
        WHEN rp.RecentPostRank = 2 THEN 'Second Most Recent Post'
        ELSE 'Older Post'
    END AS PostAgeCategory,
    DATEDIFF(SECOND, rp.CreationDate, CAST('2024-10-01 12:34:56' AS DATETIME)) AS AgeInSeconds
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    ClosedPostReasons cpr ON rp.PostId = cpr.PostId
WHERE 
    ISNULL(pvs.UpVotes, 0) - ISNULL(pvs.DownVotes, 0) > 0
    AND rp.RecentPostRank <= 2  
ORDER BY 
    pvs.UpVotes DESC, 
    rp.CreationDate ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
