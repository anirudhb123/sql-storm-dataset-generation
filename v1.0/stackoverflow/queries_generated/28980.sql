WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2 -- Counting Answers
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ur.UserId,
        ur.DisplayName AS OwnerDisplayName,
        ur.Reputation AS OwnerReputation,
        ur.AnswerCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.TagRank <= 3 -- Top 3 recent posts per tag
)
SELECT 
    pd.Title,
    pd.Body,
    pd.Tags,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.AnswerCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pd.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pd.PostId AND v.VoteTypeId = 2) AS UpVoteCount -- UpVotes
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC; -- Top posts by score and recency
