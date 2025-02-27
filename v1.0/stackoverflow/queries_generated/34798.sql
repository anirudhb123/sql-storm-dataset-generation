WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.Score > 0
),
TopUserPosts AS (
    SELECT 
        rp.PostId,
        u.DisplayName,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.UserPostRank <= 3 -- Top 3 questions per user
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '1 year' -- Filter to last year
    GROUP BY 
        ph.PostId
),
QuestionStats AS (
    SELECT 
        p.Id,
        COALESCE(pd.ViewCount, 0) AS TotalViews,
        COALESCE(count(c.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostDetails pd ON pd.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, pd.ViewCount
)
SELECT 
    tup.PostId,
    tup.DisplayName,
    tup.Title,
    tup.Score,
    qs.TotalViews,
    qs.CommentCount,
    phd.LastEditDate,
    phd.HistoryTypes
FROM 
    TopUserPosts tup
JOIN 
    QuestionStats qs ON tup.PostId = qs.Id
LEFT JOIN 
    PostHistoryDetails phd ON tup.PostId = phd.PostId
WHERE 
    qs.TotalViews > 1000 -- Only questions with more than 1000 views
ORDER BY 
    tup.Score DESC, 
    qs.TotalViews DESC
LIMIT 50;
