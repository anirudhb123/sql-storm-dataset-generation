WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
CommentDetails AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Author,
    COALESCE(av.UpVotes, 0) AS UpVotes,
    COALESCE(av.DownVotes, 0) AS DownVotes,
    cd.CommentCount,
    cd.LastCommentDate,
    (DATEDIFF(MINUTE, rp.CreationDate, GETDATE())) / 60 AS AgeInHours,
    CASE 
        WHEN php.LastEditDate IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedVotes av ON rp.PostId = av.PostId
LEFT JOIN 
    CommentDetails cd ON rp.PostId = cd.PostId
LEFT JOIN 
    RecentPostHistory php ON rp.PostId = php.PostId
WHERE 
    rp.PostRank <= 5 -- Get top 5 posts per type
ORDER BY 
    rp.PostId;
