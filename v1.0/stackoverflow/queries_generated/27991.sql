WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        t.TagName AS TagName,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(a.Body, 'No accepted answer') AS AcceptedAnswerBody,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(substring(p.Tags from '\\{2}(.*)\\{2}')::varchar[]) -- Unpacking tags as a simplified example
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Filtering only questions
    GROUP BY 
        p.Id, u.DisplayName, t.TagName, a.Body
),
UserBadges AS (
    SELECT
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(pt.Name, ': ', ph.CreationDate::date), '; ') AS HistoryDetails
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.TagName,
    pd.AnswerCount,
    pd.CommentCount,
    pd.AcceptedAnswerBody,
    pd.UpVotes,
    pd.DownVotes,
    ub.BadgeNames,
    ph.HistoryDetails
FROM 
    PostDetails pd
LEFT JOIN 
    UserBadges ub ON pd.OwnerDisplayName = ub.UserId
LEFT JOIN 
    PostHistoryInfo ph ON pd.PostId = ph.PostId
ORDER BY 
    pd.ViewCount DESC
LIMIT 100;
