WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Selecting only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
),
MostVotedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 2 -- UpMod votes
    WHERE 
        rp.Rank <= 5 -- Top 5 questions per tag
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags, rp.CreationDate, rp.Score, rp.ViewCount
),
EnhancedPosts AS (
    SELECT 
        mp.PostId,
        mp.Title,
        mp.Tags,
        mp.CreationDate,
        mp.Score,
        mp.ViewCount,
        mp.VoteCount,
        ARRAY_AGG(CASE WHEN c.PostId IS NOT NULL THEN c.Text END) AS Comments
    FROM 
        MostVotedPosts mp
    LEFT JOIN 
        Comments c ON mp.PostId = c.PostId
    GROUP BY 
        mp.PostId, mp.Title, mp.Tags, mp.CreationDate, mp.Score, mp.ViewCount, mp.VoteCount
)
SELECT 
    ep.PostId,
    ep.Title,
    ep.Tags,
    ep.CreationDate,
    ep.Score,
    ep.ViewCount,
    ep.VoteCount,
    CASE 
        WHEN ep.VoteCount > 10 THEN 'Popular'
        WHEN ep.VoteCount BETWEEN 5 AND 10 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS Popularity,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS Commenters
FROM 
    EnhancedPosts ep
LEFT JOIN 
    Users u ON u.Id IN (SELECT DISTINCT c.UserId FROM Comments c WHERE c.PostId = ep.PostId)
GROUP BY 
    ep.PostId, ep.Title, ep.Tags, ep.CreationDate, ep.Score, ep.ViewCount, ep.VoteCount
ORDER BY 
    ep.VoteCount DESC, ep.Score DESC, ep.CreationDate DESC;
