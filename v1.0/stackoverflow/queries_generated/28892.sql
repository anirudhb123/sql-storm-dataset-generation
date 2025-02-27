WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS NumUpVotes,
        COALESCE(v.DownVotes, 0) AS NumDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
             PostId, 
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
             SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
             Votes 
         GROUP BY 
             PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]) -- Extracting tags from the Tags field
    WHERE 
        p.PostTypeId IN (1, 2) -- Only considering Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName, v.UpVotes, v.DownVotes
    HAVING 
        COUNT(t.Id) >= 2 -- Ensure at least two different tags are present
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.TagList,
        rp.NumUpVotes,
        rp.NumDownVotes,
        us.TotalBadges,
        us.TotalAnswers,
        us.TotalViews,
        us.TotalComments
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.RN <= 5 -- Get only the last 5 posts for each user
)

SELECT 
    *,
    CASE 
        WHEN NumUpVotes - NumDownVotes > 0 THEN 'Positive'
        WHEN NumUpVotes - NumDownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    FinalResults
ORDER BY 
    CreationDate DESC
LIMIT 50; -- Limit to the most recent 50 results
