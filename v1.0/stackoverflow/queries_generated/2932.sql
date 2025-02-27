WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AnnouncementDate, CURRENT_TIMESTAMP) AS AnnouncementDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
), 
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.UpVotesCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 10 OR rp.UpVotesCount > 100
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
)
SELECT 
    pp.Title,
    pp.CommentCount,
    pp.UpVotesCount,
    COALESCE(ph.HistoryDate, 'No History') AS LastHistoryDate,
    ph.Comment AS HistoryComment
FROM 
    PopularPosts pp
LEFT JOIN 
    PostHistoryInfo ph ON pp.PostId = ph.PostId AND ph.HistoryRank = 1
WHERE 
    pp.CommentCount > 0
ORDER BY 
    pp.UpVotesCount DESC, pp.CommentCount DESC;
