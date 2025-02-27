WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Within the last year
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        TagCount,
        OwnerDisplayName,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 100 -- Top 100 Posts based on Score and ViewCount
),
PostVoteCount AS (
    SELECT 
        PostId, 
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS UpVotes, -- UpMod votes
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS DownVotes -- DownMod votes
    FROM 
        Votes 
    GROUP BY 
        PostId
),
PostWithVotes AS (
    SELECT 
        trp.*,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        PostVoteCount pvc ON trp.PostId = pvc.PostId
)
SELECT 
    pwv.PostId,
    pwv.Title,
    pwv.CreationDate,
    pwv.Score,
    pwv.ViewCount,
    pwv.TagCount,
    pwv.OwnerDisplayName,
    pwv.OwnerReputation,
    pwv.UpVotes,
    pwv.DownVotes,
    (pwv.UpVotes - pwv.DownVotes) AS NetVotes,
    (EXTRACT(EPOCH FROM NOW() - pwv.CreationDate) / 3600) AS HoursSinceCreation
FROM 
    PostWithVotes pwv
WHERE 
    pwv.UpVotes > pwv.DownVotes -- Only considering posts with more upvotes than downvotes
ORDER BY 
    NetVotes DESC, pwv.Score DESC;
