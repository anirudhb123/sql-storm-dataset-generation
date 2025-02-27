
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerDisplayName,
        p.Tags,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURDATE() - INTERVAL 1 YEAR) 
        AND p.ViewCount > 100 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerDisplayName, p.Tags, p.ViewCount
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Tags,
        rp.ViewCount,
        rp.PostRank,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS PopularityRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1  
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.PopularityRank,
    COALESCE(SUBSTRING_INDEX(p.Tags, '<', 1), 'No Tags') AS MainTag,
    CASE 
        WHEN p.DownVoteCount > p.UpVoteCount THEN 'More Downvotes'
        WHEN p.UpVoteCount > p.DownVoteCount THEN 'More Upvotes'
        ELSE 'Equal Votes'
    END AS VoteSummary
FROM 
    PopularPosts p
WHERE 
    p.PopularityRank <= 10 
ORDER BY 
    p.PopularityRank;
