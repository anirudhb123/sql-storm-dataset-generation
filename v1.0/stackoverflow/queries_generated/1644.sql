WITH RatedPosts AS (
    SELECT 
        p.Id as PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId
),
RankedUsers AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(rp.Score), 0) AS TotalScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(rp.Score), 0) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        RatedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.*,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN rp.UpVotes - rp.DownVotes > 5 THEN 'Popular'
            WHEN rp.UpVotes - rp.DownVotes BETWEEN 1 AND 5 THEN 'Moderate'
            ELSE 'Unpopular' 
        END AS Popularity
    FROM 
        RatedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.UserPostRank <= 5
)
SELECT DISTINCT 
    tp.Title,
    tp.Positivity,
    tp.ViewCount,
    tup.DisplayName AS OwnerDisplayName,
    tup.Reputation,
    tp.CreationDate,
    COALESCE((SELECT STRING_AGG(c.Text, '; ') 
              FROM Comments c 
              WHERE c.PostId = tp.PostId), 'No comments') AS Comments
FROM 
    TopPosts tp
JOIN 
    RankedUsers tup ON tp.OwnerUserId = tup.UserId
WHERE 
    tup.UserRank <= 10
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
