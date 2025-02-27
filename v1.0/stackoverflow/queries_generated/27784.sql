WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Tags, p.OwnerDisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 -- Top 5 posts for each tag
),
PostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.Tags,
        trp.OwnerDisplayName,
        trp.AnswerCount,
        trp.UpVotes,
        trp.DownVotes,
        COALESCE(CAST(STRING_AGG(b.Name, ', ') AS varchar), 'No Badges') AS Badges
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId)
    GROUP BY 
        trp.PostId, trp.Title, trp.CreationDate, trp.Tags, trp.OwnerDisplayName,
        trp.AnswerCount, trp.UpVotes, trp.DownVotes
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Tags,
    pd.OwnerDisplayName,
    pd.AnswerCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.Badges,
    CASE 
        WHEN pd.UpVotes - pd.DownVotes > 0 THEN 'Positive'
        WHEN pd.UpVotes - pd.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    DATEDIFF(day, pd.CreationDate, CURRENT_TIMESTAMP) AS DaysSinceCreation
FROM 
    PostDetails pd
ORDER BY 
    pd.UpVotes DESC, pd.CreationDate DESC;
