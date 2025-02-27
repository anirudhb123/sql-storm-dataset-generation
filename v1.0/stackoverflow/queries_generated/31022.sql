WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
        AND ph.CreationDate >= NOW() - INTERVAL '6 months'
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate AS PostCreationDate,
        rp.LastActivityDate,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        r.VoteCount,
        r.UpVotes,
        r.DownVotes,
        cp.CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes r ON rp.PostId = r.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.Score,
    cd.PostCreationDate,
    cd.LastActivityDate,
    cd.OwnerDisplayName,
    COALESCE(cd.VoteCount, 0) AS VoteCount,
    COALESCE(cd.UpVotes, 0) AS UpVotes,
    COALESCE(cd.DownVotes, 0) AS DownVotes,
    CASE WHEN cd.CloseReason IS NOT NULL THEN 'Closed: ' || cd.CloseReason ELSE 'Open' END AS Status,
    CASE 
        WHEN cd.Score > 10 THEN 'Hot'
        WHEN cd.Score BETWEEN 5 AND 10 THEN 'Trending'
        ELSE 'New'
    END AS PostStatus
FROM 
    CombinedData cd
WHERE 
    cd.UserPostRank <= 5
ORDER BY 
    cd.Score DESC, cd.PostCreationDate DESC;
