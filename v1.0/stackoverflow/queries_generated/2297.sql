WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AnswerCount, p.ViewCount
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(MAX(b.Class), 0) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.UserId,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
TopPosts AS (
    SELECT 
        r.*,
        au.DisplayName AS OwnerDisplayName,
        au.Reputation AS OwnerReputation,
        COALESCE(cp.ClosedDate, NULL) AS ClosedDate
    FROM 
        RankedPosts r
    JOIN 
        ActiveUsers au ON r.OwnerUserId = au.Id
    LEFT JOIN 
        ClosedPosts cp ON r.Id = cp.Id
    WHERE 
        r.UserPostRank <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.AnswerCount,
    tp.ViewCount,
    tp.ClosedDate,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    CASE 
        WHEN tp.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
