
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01'::DATE)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.OwnerPostRank = 1 THEN 'Top Post'
            WHEN rp.OwnerPostRank <= 5 THEN 'High Performer'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
)
SELECT 
    tp.*,
    CASE
        WHEN tp.ViewCount > 1000 THEN 'Highly Viewed'
        WHEN tp.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Viewed'
        ELSE 'Low Visibility'
    END AS VisibilityCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC, 
    tp.Score DESC
LIMIT 50;
