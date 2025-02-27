
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
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
        p.CreationDate >= DATEADD(YEAR, -1, CAST('2024-10-01' AS DATE))
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
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
