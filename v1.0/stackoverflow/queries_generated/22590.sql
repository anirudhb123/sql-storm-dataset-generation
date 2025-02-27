WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        LAG(p.Score) OVER (ORDER BY p.CreationDate) AS PrevScore,
        CASE 
            WHEN p.ViewCount IS NULL THEN 'No Views'
            WHEN p.ViewCount < 100 THEN 'Low Views'
            WHEN p.ViewCount BETWEEN 100 AND 1000 THEN 'Moderate Views'
            ELSE 'High Views'
        END AS ViewCategory
    FROM 
        Posts p
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        rp.PrevScore,
        rp.ViewCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostTagCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        PostsTags pt ON t.Id = pt.TagId
    GROUP BY 
        t.Id
)
SELECT 
    tp.Title,
    tp.CreationDate,
    COALESCE(vc.VoteCount, 0) AS TotalVotes,
    tp.ViewCategory,
    (SELECT STRING_AGG(tag.TagName, ', ') 
     FROM PostTagCounts tag 
     JOIN PostLinks pl ON tag.TagId = pl.RelatedPostId 
     WHERE pl.PostId = tp.PostId) AS RelatedTags,
    CASE 
        WHEN tp.PrevScore IS NULL THEN 'First Post'
        WHEN tp.PrevScore < tp.Score THEN 'Score Increased'
        WHEN tp.PrevScore > tp.Score THEN 'Score Decreased'
        ELSE 'No Score Change'
    END AS ScoreChange
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteCounts vc ON tp.PostId = vc.PostId
ORDER BY 
    tp.Score DESC,
    tp.CreationDate DESC;
