WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Score, p.CreationDate, p.Tags
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        rp.Title,
        rp.Score,
        rp.Rank,
        rp.CommentCount,
        ur.Reputation,
        ur.ReputationRank
    FROM 
        RankedPosts rp
    INNER JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.Rank <= 5 AND rp.Score > 10
)
SELECT 
    fp.Title,
    fp.Score,
    fp.CommentCount,
    fp.Reputation,
    fp.ReputationRank,
    STRING_AGG(tag.TagName, ', ' ORDER BY tag.TagName) AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    LATERAL string_to_array(fp.Tags, ',') AS tag(TagName) ON TRUE
GROUP BY 
    fp.PostId, fp.Title, fp.Score, fp.CommentCount, fp.Reputation, fp.ReputationRank
ORDER BY 
    fp.Reputation DESC, fp.Score DESC
LIMIT 10;
